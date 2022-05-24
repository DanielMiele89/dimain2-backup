CREATE TABLE [Staging].[IronOfferMember_PreLaunch] (
    [IronOfferMemberID] INT      NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL,
    CONSTRAINT [PK_IronOfferMemberID] PRIMARY KEY CLUSTERED ([IronOfferMemberID] ASC)
);

