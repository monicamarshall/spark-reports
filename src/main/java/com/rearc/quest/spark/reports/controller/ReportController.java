package com.rearc.quest.spark.reports.controller;

import org.springframework.web.bind.annotation.*;

import com.rearc.quest.spark.reports.service.SparkReportService;

@RestController
@RequestMapping("/reports")
public class ReportController {

    private final SparkReportService sparkReportService;

    public ReportController(SparkReportService sparkReportService) {
        this.sparkReportService = sparkReportService;
    }

    @GetMapping("/generate")
    public String generateReports() {
        sparkReportService.generateReports();
        return "Spark reports successfully generated and uploaded in S3 reports folder!";
    }
}

