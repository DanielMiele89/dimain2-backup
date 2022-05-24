﻿CREATE TABLE [MI].[schemetransbroken] (
    [matchid]  INT     NOT NULL,
    [spend]    MONEY   NOT NULL,
    [earnings] MONEY   NOT NULL,
    [freq]     TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([matchid] ASC)
);

