CREATE TABLE [AWSFile].[AlternateLocation] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]          SMALLINT     NOT NULL,
    [PostCode]         VARCHAR (50) NOT NULL,
    [LocationFormat]   VARCHAR (50) NOT NULL,
    [LocationCategory] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AWSFile_AlternateLocation] PRIMARY KEY CLUSTERED ([ID] ASC)
);

