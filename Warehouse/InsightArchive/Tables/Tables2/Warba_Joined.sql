CREATE TABLE [InsightArchive].[Warba_Joined] (
    [narrative]    VARCHAR (101) NOT NULL,
    [MID]          VARCHAR (51)  NOT NULL,
    [spend]        NUMERIC (38)  NULL,
    [transactions] INT           NULL,
    [customers]    VARCHAR (50)  NULL,
    [mcc]          VARCHAR (4)   NULL,
    [MCCDesc]      VARCHAR (200) NULL,
    [sectorname]   VARCHAR (50)  NULL,
    [BrandName]    VARCHAR (50)  NULL,
    [GroupName]    VARCHAR (50)  NULL
);

