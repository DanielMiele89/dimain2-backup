﻿CREATE TABLE [Prod].[CBP_POCClosedMembers] (
    [FanID]     INT NOT NULL,
    [IsOmitted] BIT CONSTRAINT [DF_CBP_POCClosedMembers_IsOmitted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CBP_POCClosedMembers] PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 80)
);
