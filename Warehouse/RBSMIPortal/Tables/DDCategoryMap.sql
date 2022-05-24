CREATE TABLE [RBSMIPortal].[DDCategoryMap] (
    [DDCategory]     VARCHAR (50) NOT NULL,
    [PortalCategory] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_DDCategoryMap] PRIMARY KEY CLUSTERED ([DDCategory] ASC)
);

