CREATE TABLE [Relational].[SecondaryControlGroups] (
    [SecondaryControlGroupID] INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferCyclesID]       INT      NOT NULL,
    [ControlGroupID]          INT      NULL,
    [ControlGroupTypeID]      SMALLINT NOT NULL,
    PRIMARY KEY CLUSTERED ([SecondaryControlGroupID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [nix_SecondaryControlGroups_IronOfferCyclesID]
    ON [Relational].[SecondaryControlGroups]([IronOfferCyclesID] ASC);

