CREATE TABLE [Staging].[ControlSetup_Validation_VisaBarclaycardNonAAM_IronOfferCycles] (
    [ID]             INT            IDENTITY (1, 1) NOT NULL,
    [PublisherType]  VARCHAR (50)   NULL,
    [PartnerID]      INT            NULL,
    [Segment]        VARCHAR (10)   NULL,
    [IronOfferID]    INT            NULL,
    [IronOfferName]  NVARCHAR (200) NULL,
    [ControlGroupID] INT            NULL,
    [Error]          VARCHAR (200)  NULL,
    CONSTRAINT [PK_ControlSetup_Validation_VisaBarclaycardNonAAM_IronOfferCycles] PRIMARY KEY CLUSTERED ([ID] ASC)
);

