CREATE TABLE [Staging].[ControlSetup_Validation_VisaBarclaycardNonAAM_Control_Members] (
    [PublisherType]     VARCHAR (50)   NULL,
    [PartnerID]         INT            NULL,
    [ControlGroupID]    INT            NULL,
    [PartnerName]       VARCHAR (100)  NULL,
    [IronOfferName]     NVARCHAR (200) NULL,
    [StartDate]         DATE           NULL,
    [EndDate]           DATE           NULL,
    [IronOfferCyclesID] INT            NOT NULL,
    CONSTRAINT [PK_ControlSetup_Validation_VisaBarclaycardNonAAM_Control_Members] PRIMARY KEY CLUSTERED ([IronOfferCyclesID] ASC)
);

