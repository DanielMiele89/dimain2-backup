CREATE TABLE [Staging].[SSRS_R0184_MIDCheck_CorrectlySuppressedMIDs] (
    [PartnerName] NVARCHAR (100)  NOT NULL,
    [PartnerID]   INT             NOT NULL,
    [OutletID]    INT             NOT NULL,
    [Address1]    NVARCHAR (4000) NULL,
    [Address2]    NVARCHAR (4000) NULL,
    [City]        NVARCHAR (4000) NULL,
    [Postcode]    NVARCHAR (4000) NULL,
    [MerchantID]  NVARCHAR (50)   NOT NULL,
    [ChannelType] VARCHAR (7)     NULL
);

