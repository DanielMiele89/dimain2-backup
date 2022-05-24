CREATE TABLE [InsightArchive].[affinity_brand] (
    [main_brand]                VARCHAR (30)   NULL,
    [region]                    VARCHAR (30)   NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [gender]                    CHAR (1)       NULL,
    [BrandName]                 VARCHAR (50)   NOT NULL,
    [SectorName]                VARCHAR (50)   NULL,
    [GroupName]                 VARCHAR (50)   NULL,
    [brand_customers]           INT            NULL,
    [brand_total_customers]     INT            NULL,
    [brand_fb_customers]        INT            NULL,
    [total_fb_customers]        INT            NULL
);

