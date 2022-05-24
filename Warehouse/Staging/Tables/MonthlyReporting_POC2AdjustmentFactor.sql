CREATE TABLE [Staging].[MonthlyReporting_POC2AdjustmentFactor] (
    [BrandID]                  INT              NOT NULL,
    [BrandName]                VARCHAR (17)     NOT NULL,
    [ActivatedSales]           NUMERIC (9, 2)   NOT NULL,
    [ControlSales]             NUMERIC (10, 2)  NOT NULL,
    [ActivatedCount]           INT              NOT NULL,
    [ControlCount]             INT              NOT NULL,
    [Act_Spd_pp]               NUMERIC (17, 15) NOT NULL,
    [Con_Spd_pp]               NUMERIC (18, 16) NOT NULL,
    [AdjustmentFactor]         NUMERIC (16, 15) NOT NULL,
    [AdjustmentFactor_Offline] NUMERIC (16, 16) NOT NULL,
    [AdjustmentFactor_Online]  NUMERIC (17, 16) NOT NULL,
    [PartnerID]                INT              NULL
);

