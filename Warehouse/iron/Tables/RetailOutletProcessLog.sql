CREATE TABLE [iron].[RetailOutletProcessLog] (
    [ID]                     INT            IDENTITY (1, 1) NOT NULL,
    [RetailOutletID]         INT            NULL,
    [PartnerID]              INT            NULL,
    [MerchantID]             NVARCHAR (50)  NULL,
    [Narrative]              VARCHAR (25)   NULL,
    [MCC]                    VARCHAR (4)    NULL,
    [Address1]               NVARCHAR (100) NULL,
    [Address2]               NVARCHAR (100) NULL,
    [City]                   NVARCHAR (100) NULL,
    [Postcode]               NVARCHAR (20)  NULL,
    [County]                 NVARCHAR (100) NULL,
    [Telephone]              NVARCHAR (50)  NULL,
    [PartnerOutletReference] NVARCHAR (20)  NULL,
    [Channel]                TINYINT        NOT NULL,
    [SuppressFromSearch]     BIT            NOT NULL,
    [IsUpdate]               BIT            NOT NULL,
    [Processed]              BIT            NOT NULL,
    [ProcessedDate]          DATETIME       NULL
);

