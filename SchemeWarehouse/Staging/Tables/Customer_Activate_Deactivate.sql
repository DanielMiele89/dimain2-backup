CREATE TABLE [Staging].[Customer_Activate_Deactivate] (
    [ID]              INT  IDENTITY (1, 1) NOT NULL,
    [FanID]           INT  NOT NULL,
    [ClubID]          INT  NOT NULL,
    [AgreedTCsDate]   DATE NOT NULL,
    [DeactivatedDate] DATE NOT NULL,
    [Optout_Date]     DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

