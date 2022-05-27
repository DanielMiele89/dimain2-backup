CREATE TABLE [Relational].[SecondaryControlGroups_20220119] (
    [SecondaryControlGroupID] INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferCyclesID]       INT      NOT NULL,
    [ControlGroupID]          INT      NULL,
    [ControlGroupTypeID]      SMALLINT NOT NULL
);

