CREATE TABLE [Staging].[ControlSetup_Validation_AMEX_Control_Members] (
    [PublisherType]      VARCHAR (50) NULL,
    [PartnerID]          INT          NULL,
    [AmexControlGroupID] INT          NULL,
    [AmexIronOfferID]    INT          NOT NULL,
    [OfferCyclesID]      INT          NOT NULL,
    [TargetAudience]     VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_Validation_AMEX_Control_Members] PRIMARY KEY CLUSTERED ([AmexIronOfferID] ASC, [OfferCyclesID] ASC)
);

