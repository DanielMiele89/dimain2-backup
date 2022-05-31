CREATE TABLE [Vernon].[brand_overview_HML_Profile_test] (
    [gender]           CHAR (1)       NULL,
    [Age_Group]        VARCHAR (12)   NULL,
    [Region]           VARCHAR (30)   NULL,
    [PostCodeDistrict] VARCHAR (4)    NULL,
    [Social_Class]     NVARCHAR (255) NULL,
    [CAMEO_CODE_GRP]   VARCHAR (151)  NOT NULL,
    [HML_Flag]         VARCHAR (21)   NOT NULL,
    [spend]            MONEY          NULL,
    [transactions]     INT            NULL,
    [customers]        INT            NULL
);

