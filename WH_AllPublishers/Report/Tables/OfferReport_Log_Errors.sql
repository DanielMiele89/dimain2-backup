CREATE TABLE [Report].[OfferReport_Log_Errors] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [LogID]        INT           NOT NULL,
    [ErrorDetails] VARCHAR (200) NULL,
    [ErrorDate]    DATE          DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

