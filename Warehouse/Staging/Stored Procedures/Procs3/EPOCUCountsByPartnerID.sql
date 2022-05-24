
-- =============================================
-- Author:		Edward Mace	
-- Create date: 15/02/2012
-- Description:	Gives the Original EPOCU Counts for the entered partnerID
-- =============================================
CREATE PROCEDURE [Staging].[EPOCUCountsByPartnerID] --3997
@PartnerID int
AS
BEGIN
 DECLARE @TotCust int
 DECLARE @TotE float
 DECLARE @TotP float
 DECLARE @TotO float
 DECLARE @TotC float
 DECLARE @TotU float
 DECLARE @Text varchar(2000)
 DECLARE @SQL varchar(2000)

-- Get Total Customers 
 SET @TotCust = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName
HAVING      (Relational.Partner.PartnerID = @PartnerID))

-- Get Total Customers
SET @TotE = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName, Relational.Segment.SegmentCode
HAVING      (Relational.Partner.PartnerID = @PartnerID) AND (Relational.Segment.SegmentCode = 'E'))
SET @TotP = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName, Relational.Segment.SegmentCode
HAVING      (Relational.Partner.PartnerID = @PartnerID) AND (Relational.Segment.SegmentCode = 'P'))

SET @TotO = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName, Relational.Segment.SegmentCode
HAVING      (Relational.Partner.PartnerID = @PartnerID) AND (Relational.Segment.SegmentCode = 'O'))

SET @TotC = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName, Relational.Segment.SegmentCode
HAVING      (Relational.Partner.PartnerID = @PartnerID) AND (Relational.Segment.SegmentCode = 'C'))

SET @TotU = (SELECT     COUNT(Relational.Segment.FanID) AS Counter
FROM         Relational.Segment INNER JOIN
                      Relational.Partner ON Relational.Segment.PartnerID = Relational.Partner.PartnerID INNER JOIN
                      Relational.Customer ON Relational.Segment.FanID = Relational.Customer.FanID
WHERE     (Relational.Customer.TreatmentGroup IN (2, 3, 4, 5, 6, 8, 9, 10, 22))
GROUP BY Relational.Partner.PartnerID, Relational.Partner.PartnerName, Relational.Segment.SegmentCode
HAVING      (Relational.Partner.PartnerID = @PartnerID) AND (Relational.Segment.SegmentCode = 'U'))
		
PRINT 'EPOCU Results for PartnerID  ' + convert(varchar(4), @PartnerID)
PRINT CONVERT(varchar(30),@TotCust) + '     Total Customers'
Print CONVERT(varchar(30), @TotE/@TotCust) + '          ' + CONVERT(varchar(30),@TotE) + '     in E'
Print CONVERT(varchar(30),@TotP/@TotCust) + '          ' + CONVERT(varchar(30),@TotP)+ '     in P'
Print CONVERT(varchar(30),@TotO/@TotCust) + '          '  + CONVERT(varchar(30),@TotO)+ '     in O'
Print CONVERT(varchar(30),@TotC/@TotCust) + '          '  + CONVERT(varchar(30),@TotC)+ '     in C'
Print CONVERT(varchar(30),@TotU/@TotCust) + '          '  + CONVERT(varchar(30),@TotU)+ '     in U'
END