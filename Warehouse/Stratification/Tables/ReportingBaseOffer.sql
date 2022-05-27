CREATE TABLE [Stratification].[ReportingBaseOffer] (
    [PartnerID]           INT          NULL,
    [BaseOfferID]         INT          NULL,
    [FirstReportingMonth] INT          NOT NULL,
    [LastReportingMonth]  INT          NULL,
    [ClientServicesRef]   VARCHAR (40) NULL,
    [AdjFactor]           FLOAT (53)   NULL
);

