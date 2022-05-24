CREATE TABLE [Trans].[MCCExclusionList_QualifyingSepnd] (
    [MCCID]   SMALLINT      NOT NULL,
    [MCC]     VARCHAR (4)   NOT NULL,
    [MCCDesc] VARCHAR (200) NOT NULL,
    [Notes]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Trans_MCCList] PRIMARY KEY CLUSTERED ([MCCID] ASC)
);

