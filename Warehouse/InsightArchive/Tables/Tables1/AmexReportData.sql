CREATE TABLE [InsightArchive].[AmexReportData] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [ReportDate]       DATE         NOT NULL,
    [IronOfferID]      INT          NOT NULL,
    [AmexOfferID]      VARCHAR (10) NOT NULL,
    [SpendStretch]     MONEY        NOT NULL,
    [CashbackOffer]    FLOAT (53)   NOT NULL,
    [TargetAudience]   VARCHAR (50) NOT NULL,
    [RetailerName]     VARCHAR (50) NOT NULL,
    [Exposed_Base]     INT          NOT NULL,
    [Enrolments]       INT          NOT NULL,
    [Redemptions]      INT          NULL,
    [Redemption_Value] MONEY        NULL,
    [NumberOfTrans]    INT          NULL,
    [Total_Value]      MONEY        NULL,
    [Campaign_Length]  SMALLINT     NOT NULL,
    [StartDate]        DATE         NOT NULL,
    [EndDate]          DATE         NOT NULL,
    [No_Of_Weeks_In]   SMALLINT     NOT NULL,
    [No_Of_Waves_In]   SMALLINT     NOT NULL,
    [EndOfWave]        BIT          NOT NULL
);

