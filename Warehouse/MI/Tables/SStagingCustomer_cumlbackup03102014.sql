CREATE TABLE [MI].[SStagingCustomer_cumlbackup03102014] (
    [id]                INT          IDENTITY (1, 1) NOT NULL,
    [monthID]           INT          NOT NULL,
    [LabelID]           INT          NOT NULL,
    [FanID]             INT          NOT NULL,
    [Label]             VARCHAR (50) NOT NULL,
    [LastMonthID]       INT          NULL,
    [IronOfferID]       INT          NULL,
    [ClientServicesRef] VARCHAR (50) NULL,
    [PartnerID]         INT          NULL,
    [StartDate]         DATETIME     NULL,
    [EndDate]           DATETIME     NULL
);

