CREATE TABLE [Staging].[R_0126_SampleCustomers] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (40)   NOT NULL,
    [IronOfferID]       INT            NOT NULL,
    [IronOfferName]     NVARCHAR (200) NOT NULL,
    [TopCashBackRate]   REAL           NULL,
    [StartDate]         DATETIME       NOT NULL,
    [EndDate]           DATETIME       NULL,
    [CompositeID]       BIGINT         NOT NULL,
    [Email]             VARCHAR (100)  NULL,
    [ClubID]            INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

