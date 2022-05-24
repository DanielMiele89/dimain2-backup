CREATE TABLE [Prototype].[__ROCShopperSegment_PreSelections_Archived] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [EmailDate] DATE          NULL,
    [Query]     VARCHAR (MAX) NULL,
    [PartnerID] INT           NULL,
    [isRun]     BIT           DEFAULT ((0)) NULL,
    [RunDate]   DATETIME      NULL,
    [isError]   BIT           DEFAULT ((0)) NULL,
    [ErrorInfo] VARCHAR (300) NULL,
    [Notes]     VARCHAR (400) NULL
);

