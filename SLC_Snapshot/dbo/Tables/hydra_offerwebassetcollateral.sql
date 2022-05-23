CREATE TABLE [dbo].[hydra_offerwebassetcollateral] (
    [offerwebassetcollateralid] NVARCHAR (50)   NOT NULL,
    [offerid]                   NVARCHAR (50)   NOT NULL,
    [bannertitle]               NVARCHAR (50)   NOT NULL,
    [logo]                      NVARCHAR (150)  NULL,
    [logothumbnail]             NVARCHAR (150)  NULL,
    [longcopy]                  NVARCHAR (2250) NOT NULL,
    [marketingratedisplaytext]  NVARCHAR (50)   NOT NULL,
    [offerheader]               NVARCHAR (100)  NOT NULL,
    [prioritisationscore]       INT             NOT NULL,
    [shortcopy]                 NVARCHAR (950)  NOT NULL,
    [websiteurldisplaytext]     NVARCHAR (50)   NOT NULL,
    [websiteurllink]            NVARCHAR (150)  NOT NULL,
    [createddate]               DATETIME2 (7)   NOT NULL,
    [modifieddate]              DATETIME2 (7)   NOT NULL,
    [deleteddate]               NVARCHAR (1)    NULL,
    [deleted]                   BIT             NOT NULL,
    [carouselbackground]        NVARCHAR (150)  NULL,
    [carousellogo]              NVARCHAR (150)  NULL,
    CONSTRAINT [PK_Hydra_OfferWebAssetCollateral] PRIMARY KEY CLUSTERED ([offerwebassetcollateralid] ASC)
);

