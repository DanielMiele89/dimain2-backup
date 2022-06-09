CREATE TABLE [dbo].[CollateralType] (
    [ID]                 INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [MediaTypeID]        INT            NOT NULL,
    [ChannelID]          INT            NOT NULL,
    [CollateralTypeName] NVARCHAR (45)  NULL,
    [Mandatory]          TINYINT        NULL,
    [FilePath]           NVARCHAR (45)  NULL,
    [FileNameFormat]     NVARCHAR (45)  NULL,
    [UrlPrefix]          NVARCHAR (100) NULL,
    [DimensionX]         INT            NULL,
    [DimensionY]         INT            NULL,
    [MaxLength]          INT            NULL,
    [DisplayOrder]       INT            NULL,
    [Size]               VARCHAR (25)   NULL,
    CONSTRAINT [PK_CollateralType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [uqc_CollateralTypeName] UNIQUE NONCLUSTERED ([CollateralTypeName] ASC)
);

