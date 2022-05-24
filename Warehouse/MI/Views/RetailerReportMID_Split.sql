
CREATE VIEW MI.RetailerReportMID_Split
AS SELECT a.ID Mid_SplitID , 
		a.StatusTypeID as ReportMID_StatusTypeID ,
		a.SplitID as ReportMID_SplitID , 
          a.PartnerID , 
          ra.StatusTypeDesc StatusDescription , 
          b.Use_For_Report SplitPosition , 
          a.Use_For_Report StatusPosition , 
          CASE
          WHEN b.DeafultStatusTypeID
               =
               a.Use_For_Report THEN 1
              ELSE 0
          END DefaultStatus
     FROM
          Warehouse.MI.ReportStatusTypeUseforReport a INNER JOIN Warehouse.MI.ReportSplitUseforReport b
          ON a.PartnerID
             =
             b.PartnerID
         AND a.SplitID
             =
             b.Splitid
                                                      INNER JOIN Warehouse.MI.ReportMIDSplit rb
          ON rb.splitid
             =
             b.splitid
                                                      INNER JOIN Warehouse.MI.ReportMIDStatus ra
          ON ra.SplitID
             =
             a.SplitID
         AND ra.StatusTypeID
             =
             a.StatusTypeID
     WHERE a.Use_For_Report
           >
           0
       AND b.Use_For_Report
           >
           0;