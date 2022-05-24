CREATE TABLE [InsightArchive].[MIDsToBeSuppressed_20181024] (
    [PartnerName]        NVARCHAR (100) NOT NULL,
    [PartnerID]          INT            NOT NULL,
    [RetailOutletID]     INT            NOT NULL,
    [MerchantID]         NVARCHAR (50)  NOT NULL,
    [SuppressFromSearch] BIT            NOT NULL,
    [ToBeSuppressed]     INT            NOT NULL,
    [Address1]           NVARCHAR (100) NOT NULL,
    [Address2]           NVARCHAR (100) NOT NULL,
    [City]               NVARCHAR (100) NOT NULL,
    [Postcode]           NVARCHAR (20)  NOT NULL,
    [Instances]          INT            NULL,
    [CountSuppressed]    INT            NULL,
    [LatestTran]         DATE           NULL,
    [TotalTransAmount]   MONEY          NULL,
    [TransCount]         INT            NULL,
    [SuppressedScore]    BIGINT         NULL
);

