CREATE TABLE [Reporting].[ERF_Report_Reductions] (
    [MonthDate]       NVARCHAR (43) NOT NULL,
    [SourceName]      VARCHAR (50)  NOT NULL,
    [DisplayName]     VARCHAR (103) NULL,
    [PaymentMethod]   VARCHAR (7)   NOT NULL,
    [PublisherName]   VARCHAR (100) NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [Earnings]        MONEY         NULL,
    [PartnerID]       INT           NOT NULL,
    [EarningSourceID] INT           NULL,
    [DDCategory]      VARCHAR (50)  NOT NULL
);

