package com.rearc.quest.spark.reports.service;

import static org.apache.spark.sql.functions.col;
import static org.apache.spark.sql.functions.explode;
import static org.apache.spark.sql.functions.mean;
import static org.apache.spark.sql.functions.row_number;
import static org.apache.spark.sql.functions.stddev;
import static org.apache.spark.sql.functions.sum;

import java.io.IOException;
import java.net.URI;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SaveMode;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.expressions.Window;
import org.apache.spark.sql.expressions.WindowSpec;
import org.apache.spark.sql.types.DataTypes;
import org.springframework.stereotype.Service;

@Service
public class SparkReportService {

	private final String basePath = "s3a://s3upload-lambda-bucket/bls-gov-datausa/";
	private final String reportsBase = "s3a://s3upload-lambda-bucket/reports/";

	public void generateReports() {

		SparkSession spark = SparkSession.builder()
				.appName("BLS Data Analytics Reports")
				.master("local[*]")
				// Disable Spark Web UI to avoid javax.servlet conflict
				.config("spark.ui.enabled", "false")
				.config("spark.metrics.conf", "metrics.properties")
				.config("spark.hadoop.fs.s3a.access.key", System.getenv("AWS_ACCESS_KEY_ID"))
				.config("spark.hadoop.fs.s3a.secret.key", System.getenv("AWS_SECRET_ACCESS_KEY"))
				.config("spark.hadoop.fs.s3a.endpoint", "s3.us-east-2.amazonaws.com")
				.config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
				.getOrCreate();
		try {
			generatePopulationStats(spark);
			generateBestYearReport(spark);
		} finally {
			spark.stop();
		}
	}

	private void generatePopulationStats(SparkSession spark) {

		// Generate population stats
		Dataset<Row> dfPopulationRaw = spark.read().json(basePath + "population.json");

		Dataset<Row> exploded = dfPopulationRaw.withColumn("data_row", explode(col("data")));
		exploded.printSchema();

		// Step 1: Explode the 'data' array
		Dataset<Row> dfExploded = dfPopulationRaw.withColumn("entry", explode(col("data")));

		// Step 2: Extract relevant fields
		Dataset<Row> dfPopulation = dfExploded.select(col("entry.Year").alias("Year"),
				col("entry.Population").alias("Population"));

		// Step 3: Filter and compute stats
		Dataset<Row> popStats = dfPopulation.filter(col("Year").geq(2013).and(col("Year").leq(2018)))
				.select(mean("Population").alias("mean_population"), stddev("Population").alias("stddev_population"));

		String timestampPop = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS"));
		String finalPopPath = reportsBase + "population_stats_" + timestampPop + ".csv";
		String tempPopPath = reportsBase + "population_stats_temp";

		popStats.coalesce(1).write().mode(SaveMode.Overwrite).option("header", true).csv(tempPopPath);

		renameSingleCSV(spark, tempPopPath, finalPopPath);
		System.out.println("Reports generated successfully in: " + reportsBase);
	}

	private void generateBestYearReport(SparkSession spark) {

		// Generate best-year report
		Dataset<Row> dfCurrent = spark.read().option("header", true).option("delimiter", "\t")
				.option("ignoreLeadingWhiteSpace", true).option("ignoreTrailingWhiteSpace", true)
				.csv(basePath + "pr.data.0.Current").withColumn("value", col("value").cast(DataTypes.DoubleType))
				.withColumn("year", col("year").cast(DataTypes.IntegerType));

		dfCurrent.printSchema();
		dfCurrent.show(5);

		Dataset<Row> dfYearlySum = dfCurrent.groupBy("series_id", "year").agg(sum("value").alias("value"));

		WindowSpec w = Window.partitionBy("series_id").orderBy(col("value").desc());
		Dataset<Row> dfBestYear = dfYearlySum.withColumn("rank", row_number().over(w)).filter(col("rank").equalTo(1))
				.drop("rank").orderBy("series_id");

		String timestampBest = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS"));
		String finalBestYearPath = reportsBase + "best_year_report_" + timestampBest + ".csv";
		String tempBestYearPath = reportsBase + "best_year_report_temp";

		dfBestYear.coalesce(1).write().mode(SaveMode.Overwrite).option("header", true).csv(tempBestYearPath);

		renameSingleCSV(spark, tempBestYearPath, finalBestYearPath);

		System.out.println("Reports generated successfully in: " + reportsBase);

	}

	/**
	 * Renames the single CSV part file to the final target in S3 and cleans up temp
	 * folder
	 */
	private void renameSingleCSV(SparkSession spark, String tempPathStr, String finalPathStr) {
		try {
			Configuration hadoopConf = spark.sparkContext().hadoopConfiguration();
			FileSystem fs = FileSystem.get(URI.create(tempPathStr), hadoopConf);

			Path tempPath = new Path(tempPathStr);
			Path finalPath = new Path(finalPathStr);

			for (org.apache.hadoop.fs.FileStatus fileStatus : fs.listStatus(tempPath)) {
				String name = fileStatus.getPath().getName();
				if (name.startsWith("part-") && name.endsWith(".csv")) {
					try {
						fs.rename(fileStatus.getPath(), finalPath);
						System.out.println("Renamed " + name + " to " + finalPathStr);
					} catch (IOException e) {
						throw new RuntimeException("Failed to rename file in S3", e);
					}
				}
			}

			fs.delete(tempPath, true);
		} catch (IOException e) {
			throw new RuntimeException("Error during CSV renaming in S3", e);
		}
	}
}