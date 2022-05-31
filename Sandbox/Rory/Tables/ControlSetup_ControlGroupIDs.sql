﻿CREATE TABLE [Rory].[ControlSetup_ControlGroupIDs] (
    [ControlGroupID]             INT          NULL,
    [RetailerID]                 INT          NULL,
    [SegmentID]                  INT          NULL,
    [IsUniversal]                BIT          NOT NULL,
    [IsInPromgrammeControlGroup] BIT          NOT NULL,
    [PublisherID]                INT          NULL,
    [OfferID]                    INT          NULL,
    [StartDate]                  DATETIME     NOT NULL,
    [EndDate]                    DATETIME     NOT NULL,
    [IsSegmented]                BIT          NULL,
    [OriginalControlGroupID]     INT          NULL,
    [OriginalTableSource]        VARCHAR (50) NULL
);

