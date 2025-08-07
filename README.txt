PS C:\data\EclipseAWSLambda\reports-demo> mvn clean package -DskipTests 
PS C:\data\EclipseAWSLambda\reports-demo> docker build -t spark-spring-boot:1.0.0 . 
PS C:\data\EclipseAWSLambda\reports-demo> docker run -it --rm -p 8080:8080 
-e AWS_ACCESS_KEY_ID=******************* 
-e AWS_SECRET_ACCESS_KEY=***************  spark-spring-boot:1.0.0

pr.data.0.Current and population.json file are loaded as dataframes with Spark

Using the population dataframe the mean and the standard deviation 
of the annual US population across the years [2013, 2018] inclusive are created.

Using the dataframe from pr.data.0.Current, for every series_id, 
find the best year: the year with the max/largest sum of "value" 
for all quarters in that year. 

A report is generated with each series id, 
the best year for that series, 
and the summed value for that year. 

For example, the values look like this:

series_id	year	period	value
PRS30006011	1995	Q01	1
PRS30006011	1995	Q02	2
PRS30006011	1996	Q01	3
PRS30006011	1996	Q02	4
PRS30006012	2000	Q01	0
PRS30006012	2000	Q02	8
PRS30006012	2001	Q01	2
PRS30006012	2001	Q02	3
the report would generate the following table:

series_id	year	value
PRS30006011	1996	7
PRS30006012	2000	8

Using both dataframes 
a report is generated that provides the value 
for series_id = PRS30006032 and period = Q01 
and the population for that given year 
(if available in the population dataset). 
The below table shows an example of one row that might appear in the resulting table:

series_id	year	period	value	Population
PRS30006032	2018	Q01	1.9	327167439
