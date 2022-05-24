-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR115_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)


IF OBJECT_ID('tempdb..#Responders') IS NOT NULL DROP TABLE #Responders
SELECT   F.CINID
INTO #Responders
FROM #FB F
JOIN WH_Visa.Derived.PartnerTrans PT on Pt.FanID = F.FanID
WHERE PT.PartnerID = 4263
AND TransactionDate BETWEEN '2021-08-19' AND '2021-09-22'
AND TransactionAmount > 0
AND PT.IronOfferID IN (-1081,-1082,-1080)
CREATE CLUSTERED INDEX cix_CINID ON #Responders(CINID)

-- Iron Offer (MOR103/NationalTrade/Acquire, MOR103/NationalTrade/Lapsed, MOR107/LowSoW/Shopper) spenders
IF OBJECT_ID('Sandbox.rukank.Barclays_Morrisons_Nursery_21092021') IS NOT NULL DROP TABLE Sandbox.rukank.Barclays_Morrisons_Nursery_21092021
SELECT	F.CINID
INTO Sandbox.rukank.Barclays_Morrisons_Nursery_21092021
FROM #Responders F
GROUP BY F.CINID
If Object_ID('WH_Visa.Selections.MOR115_PreSelection') Is Not Null Drop Table WH_Visa.Selections.MOR115_PreSelectionSelect FanIDInto WH_Visa.Selections.MOR115_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.Barclays_Morrisons_Nursery_21092021 st				WHERE fb.CINID = st.CINID)END


