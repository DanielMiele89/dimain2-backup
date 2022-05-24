-- =============================================
-- Author:		<Phil L>
-- Create date: <02/07/2015>
-- Description:	<Code to generate the base table for this weeks Parter MTR>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[AllPartner_WMTR_Build]
	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;




    -- Insert statements for procedure here
--	SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

/* Index

A - Preparations

A01 - Date range and variable definitions

A02 - Build the standard customer base

A03 - Build the partner list

A04 - Build the competitor list

A05 - build the Consumercombination list

A06 - Construct the output and transaction tables


B - Data gathering

B01 - get all the transactions for the partners and competitors


C - Calculations

C01 - generate output tables

D - Cleanup

D01 - Drop unnecessary tables

*/

/* Section A */
/* A01 -  Date range and variable definitions */

DECLARE @CY_sdate	DATE
		,@CY_edate	DATE
		,@PY_sdate	DATE
		,@PY_edate	DATE
		,@loop		INT
		,@lastloop	INT


SET @CY_edate = DATEADD(dd,-7,GETDATE())
SET @CY_sdate = dateadd(dd,-7,@CY_edate)
SET @PY_edate = dateadd(dd,-365,@CY_edate)
SET @PY_sdate = dateadd(dd,-7,@PY_edate)

;


/* A02 - Build the standard customer base */

--RUN TIME C.40MIN
EXEC Relational.CustomerBase_Generate 'AllPartners_WMTR', @PY_sdate, @cy_edate -- THIS TABLE needs to be created
;


/* A03 - Build the partner & competitor tables */
 IF OBJECT_ID('TEMPDB..#Targets') IS NOT NULL DROP TABLE #Targets
 CREATE TABLE #Targets	(	partnerID	INT 
							,brandid	INT 
							,brandname	VARCHAR(255)
							,IS_partner	TINYINT	DEFAULT 0 --1 indicates a partner
						)
;


--Partners
INSERT INTO #Targets

SELECT partnerID
		,brandid
		,PartnerName
		,1
FROM warehouse.relational.Partner
WHERE brandid IS NOT NULL
  AND currentlyactive = 1
;

--competitors
INSERT INTO #Targets

SELECT p.partnerid
		,bc.competitorID
		,b.brandname
		,0

from warehouse.relational.BrandCompetitor as bc with (NOLOCK)
INNER JOIN #targets as p ON p.brandid = bc.brandid
INNER JOIN warehouse.relational.brand as b ON bc.competitorID = b.BrandID
;

select * from #Targets



/* A05 - build the Consumercombination list */

IF OBJECT_ID('TEMPDB..#consumercombination') IS NOT NULL DROP TABLE #consumercombination

CREATE TABLE #consumercombination	(consumercombination	INT NOT NULL PRIMARY KEY
										,brandid	INT NOT NULL
									)
INSERT INTO #consumercombination
SELECT cc.ConsumerCombinationID
		,cc.BrandID
FROM warehouse.relational.ConsumerCombination as cc with (NOLOCK)
where brandid IN (select distinct brandid FROM #Targets)
;


/* A06 - Construct the  transaction tables */
--PL note strip this from sandbox to tempdb when finished
IF OBJECT_ID('tempdb..#WMTR_CurrentYear') IS NOT NULL DROP TABLE #WMTR_CurrentYear;
CREATE TABLE #WMTR_CurrentYear	(	brandid			INT NOT NULL PRIMARY KEY
									,transactions	INT DEFAULT 0
									,Sales			DECIMAL(12,2) DEFAULT 0
									,customers		INT DEFAULT 0
								)
;

IF OBJECT_ID('tempdb..#WMTR_PriorYear') IS NOT NULL DROP TABLE #WMTR_PriorYear;
CREATE TABLE #WMTR_PriorYear	(	brandid			INT NOT NULL PRIMARY KEY
									,transactions	INT DEFAULT 0
									,Sales			DECIMAL(12,2) DEFAULT 0
									,customers		INT DEFAULT 0
								)
;



--output table
/*IF OBJECT_ID('warehouse.excelquery.WMTR_output') IS NOT NULL DROP TABLE warehouse.excelquery.WMTR_output;
CREATE TABLE warehouse.excelquery.WMTR_output	(partnerID			INT
										 ,brandid			INT
										 ,brandname			VARCHAR(255)
										 ,partnername		VARCHAR(255)
										 ,reportdate		DATE
										 ,CY_sales			DECIMAL(12,2)
										 ,CY_sales_share	DECIMAL(4,3)
										 ,PY_sales			DECIMAL(12,2)
										 ,PY_sales_share	DECIMAL(4,3)	
										 ,CY_txns			INT
										 ,CY_txn_share		DECIMAL(4,3)	
										 ,PY_txns			INT
										 ,PY_txn_share		DECIMAL(4,3)
										 ,CY_custs			INT
										 ,CY_cust_share		DECIMAL(4,3)	
										 ,PY_custs			INT
										 ,PY_cust_share		DECIMAL(4,3)
										 )
;
*/
/* B01 - get all the transactions for the partners and competitors */


INSERT INTO #WMTR_CurrentYear

SELECT cc.brandid
		,count (1) 
		,sum(ct.amount) 
		,count (distinct ct.cinid)

FROM warehouse.relational.ConsumerTransaction as ct with (NOLOCK)
INNER JOIN #consumercombination as cc
	ON cc.consumercombination = ct.ConsumerCombinationID
INNER JOIN warehouse.insightarchive.allpartners_WMTR as ap 
	ON ap.cinid = ct.cinid	
WHERE ct.trandate >= @CY_sdate
 AND ct.trandate <= @cy_edate

GROUP BY cc.brandid
;



INSERT INTO #WMTR_PriorYear

SELECT cc.brandid
		,count (1) 
		,sum(ct.amount) 
		,count (distinct ct.cinid)

FROM warehouse.relational.ConsumerTransaction as ct with (NOLOCK)
INNER JOIN #consumercombination as cc
	ON cc.consumercombination = ct.ConsumerCombinationID
INNER JOIN warehouse.insightarchive.allpartners_WMTR as ap 
	ON ap.cinid = ct.cinid	
WHERE ct.trandate >= @PY_sdate
 AND ct.trandate <= @PY_edate

GROUP BY cc.brandid
;



/* C01 - generate output tables */

TRUNCATE TABLE warehouse.excelquery.WMTR_output;

INSERT INTO warehouse.excelquery.WMTR_output (partnerid
										,reportdate
										,brandname
										,brandid
										,CY_custs
										,CY_sales
										,CY_txns
										,PY_custs
										,PY_sales
										,PY_txns)

SELECT t.partnerid
		,@CY_edate
		,t.brandname
		,t.brandid
		,c.customers
		,c.sales
		,c.transactions
		,p.customers
		,p.sales
		,p.transactions

FROM #Targets as t
INNER JOIN #WMTR_CurrentYear as c ON t.brandid = c.brandid
INNER JOIN #WMTR_PriorYear as p ON t.brandid = p.brandid
;

--do parter totals for working out shares
IF OBJECT_ID('tempdb..#partnertotals') IS NOT NULL DROP TABLE #partnertotals;
CREATE TABLE #partnertotals	(partnerid	INT
							,CY_custs	INT
							,CY_sales	DECIMAL(12,2)
							,CY_txns	INT
							,PY_custs	INT
							,PY_sales	DECIMAL(12,2)
							,PY_txns	INT
							)
INSERT INTO #partnertotals
SELECT partnerid
		,sum(CY_custs) 
		,SUM(CY_sales)
		,SUM(CY_txns)
		,SUM(PY_custs)	
		,SUM(PY_sales)	
		,SUM(PY_txns)
FROM warehouse.excelquery.WMTR_output
GROUP BY partnerid
;


UPDATE warehouse.excelquery.WMTR_output
SET CY_txn_share = iq.t_share
	,CY_cust_share	= iq.c_share
	,CY_sales_share = iq.s_share
	,pY_txn_share = iq.t_share_p
	,pY_cust_share	= iq.c_share_p
	,pY_sales_share = iq.s_share_p

FROM warehouse.excelquery.WMTR_output as o
INNER JOIN 	(select o.brandid
					,o.partnerid
					,convert(decimal(4,3),CONVERT(float,o.cy_sales) / pt.cy_sales) as s_share
					,convert(decimal(4,3),CONVERT(float,o.cy_txns) / pt.cy_txns)	as t_share
					,convert(decimal(4,3),CONVERT(float,o.cy_custs) / pt.cy_custs) as c_share
					,convert(decimal(4,3),CONVERT(float,o.py_sales) / pt.py_sales) as s_share_p
					,convert(decimal(4,3),CONVERT(float,o.py_txns) /  pt.py_txns)	as t_share_p
					,convert(decimal(4,3),CONVERT(float,o.py_custs) / pt.py_custs) as c_share_p
				FROM warehouse.excelquery.WMTR_output as o
				INNER JOIN #partnertotals as pt ON pt.partnerid = o.partnerid
				GROUP BY o.brandid
						,o.partnerid	
						,convert(decimal(4,3),CONVERT(float,o.cy_sales) / pt.cy_sales)
						,convert(decimal(4,3),CONVERT(float,o.cy_txns) / pt.cy_txns)	
						,convert(decimal(4,3),CONVERT(float,o.cy_custs) / pt.cy_custs)
						,convert(decimal(4,3),CONVERT(float,o.py_sales) / pt.py_sales) 
						,convert(decimal(4,3),CONVERT(float,o.py_txns) /  pt.py_txns)	
						,convert(decimal(4,3),CONVERT(float,o.py_custs) / pt.py_custs) 
					) as iq ON o.brandid = iq.brandid AND o.partnerid = iq.partnerid
;

UPDATE warehouse.excelquery.WMTR_output
SET partnername = t.brandname
FROM warehouse.excelquery.WMTR_output as o 
INNER JOIN #targets as t ON o.partnerid = t.partnerid --AND o.brandid = t.brandid
			WHERE t.is_partner = 1
;



/* D01 - Drop unnecessary tables */

DROP TABLE warehouse.insightarchive.AllPartners_WMTR;







END
