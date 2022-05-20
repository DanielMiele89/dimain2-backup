CREATE TABLE [dbo].[SLCPointsNegative] (
    [ID]          SMALLINT       NOT NULL,
    [CategoryID]  INT            NOT NULL,
    [Description] NVARCHAR (100) NOT NULL,
    [Points]      SMALLINT       NOT NULL,
    [Status]      TINYINT        NOT NULL,
    [ClubAPI]     BIT            CONSTRAINT [DF_SLCPointsNegative_ClubAPI] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SLCPointsNegative] PRIMARY KEY CLUSTERED ([ID] ASC)
);

