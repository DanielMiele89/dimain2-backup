CREATE TABLE [dbo].[Partner] (
    [ID]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]             NVARCHAR (100) NOT NULL,
    [PartnerType]      TINYINT        NOT NULL,
    [Status]           SMALLINT       NOT NULL,
    [Country]          NVARCHAR (50)  NULL,
    [CommissionRate]   FLOAT (53)     NOT NULL,
    [MerchantID]       NVARCHAR (50)  NOT NULL,
    [RegisteredName]   NVARCHAR (100) NOT NULL,
    [MerchantAcquirer] NVARCHAR (100) NULL,
    [CompanyWebsite]   NVARCHAR (100) NOT NULL,
    [FanID]            INT            NULL,
    [Matcher]          NVARCHAR (50)  NOT NULL,
    [ShowMaps]         BIT            NOT NULL,
    [ExchequerCode]    NVARCHAR (6)   NULL,
    CONSTRAINT [PK_Partner] PRIMARY KEY CLUSTERED ([ID] ASC)
);

