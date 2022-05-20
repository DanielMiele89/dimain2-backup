CREATE TABLE [dbo].[RetailOutlet] (
    [ID]                      INT               IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PartnerID]               INT               NOT NULL,
    [MerchantID]              NVARCHAR (50)     NOT NULL,
    [FanID]                   INT               NOT NULL,
    [SuppressFromSearch]      BIT               NOT NULL,
    [Channel]                 TINYINT           NOT NULL,
    [PartnerOutletReference]  NVARCHAR (20)     NULL,
    [Coordinates]             [sys].[geography] NULL,
    [GeolocationUpdateFailed] BIT               NOT NULL,
    [MerchantCategoryCode]    CHAR (4)          NULL,
    [MerchantNarrative]       NVARCHAR (50)     NULL,
    [MerchantLocation]        NVARCHAR (60)     NULL,
    [MerchantState]           NVARCHAR (3)      NULL,
    [MerchantCountry]         NVARCHAR (3)      NULL,
    CONSTRAINT [PK_RetailOutlet] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[RetailOutlet] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[RetailOutlet] TO [visa_etl_user]
    AS [dbo];

