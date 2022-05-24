CREATE TABLE [Lion].[LionSendVolumesTracking] (
    [LionSendBuildDate]             DATETIME     NULL,
    [LionSendID]                    SMALLINT     NULL,
    [EmailSendDate]                 DATE         NULL,
    [Brand]                         VARCHAR (10) NULL,
    [Loyalty]                       VARCHAR (10) NULL,
    [OffersInOPE_Combined]          INT          NULL,
    [MarketableCustomers_PreDedupe] INT          NULL,
    [Offers_Combined_PreDedupe]     INT          NULL,
    [Partners_Combined_PreDedupe]   SMALLINT     NULL,
    [OfferMemberships]              INT          NULL,
    [Offers_PerBrandLoyalty]        INT          NULL,
    [Offers_Combined]               INT          NULL,
    [Partners_PerBrandLoyalty]      SMALLINT     NULL,
    [Partners_Combined]             SMALLINT     NULL,
    [AverageSlots]                  REAL         NULL,
    [UsersSelectedForLionSend]      INT          NULL,
    [UsersExportedFromSFD]          INT          NULL,
    [UsersAfterSFDValidation]       INT          NULL,
    [UsersEmailed]                  INT          NULL
);

