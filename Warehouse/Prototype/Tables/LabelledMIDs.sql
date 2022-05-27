CREATE TABLE [Prototype].[LabelledMIDs] (
    [RetailOutletID] INT            NOT NULL,
    [PartnerID]      INT            NOT NULL,
    [MerchantID]     NVARCHAR (50)  NOT NULL,
    [PartnerName]    NVARCHAR (100) NOT NULL,
    [Channel]        TINYINT        NOT NULL,
    [IsOnline]       BIT            NULL,
    [PostCode]       NVARCHAR (20)  NULL,
    [PostalSector]   VARCHAR (6)    NULL,
    [PostArea]       VARCHAR (2)    NULL,
    [Region]         VARCHAR (30)   NULL,
    [BrandID]        INT            NULL,
    [MID_JOIN]       NVARCHAR (50)  NULL
);

