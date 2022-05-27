CREATE TABLE [Report].[OfferReport_ControlGroupMembers_Counts] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [RetailerID]     INT           NOT NULL,
    [SegmentID]      TINYINT       NOT NULL,
    [ControlGroupID] INT           NOT NULL,
    [StartDate]      DATETIME2 (7) NOT NULL,
    [EndDate]        DATETIME2 (7) NOT NULL,
    [Customers]      INT           NOT NULL,
    [AddedDate]      DATETIME2 (7) NOT NULL,
    [ModifiedDate]   DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCIX_ControlGroupMember_Counts]
    ON [Report].[OfferReport_ControlGroupMembers_Counts]([ControlGroupID] ASC, [StartDate] ASC);

