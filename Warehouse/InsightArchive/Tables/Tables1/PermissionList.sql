﻿CREATE TABLE [InsightArchive].[PermissionList] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [DBName]         VARCHAR (100) NOT NULL,
    [ObjectType]     VARCHAR (100) NOT NULL,
    [SchemaName]     VARCHAR (100) NOT NULL,
    [ObjectName]     VARCHAR (100) NOT NULL,
    [PermissionName] VARCHAR (500) NOT NULL,
    [DBUserName]     VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

