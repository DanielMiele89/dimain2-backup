﻿CREATE TABLE [Staging].[MatchCardHolderPresent] (
    [MatchID]               INT      NOT NULL,
    [CardholderPresentData] CHAR (1) NULL,
    [FileID]                INT      NULL,
    [RowNum]                INT      NULL,
    CONSTRAINT [pk_MatchCardHolderPresent] PRIMARY KEY CLUSTERED ([MatchID] ASC)
);

