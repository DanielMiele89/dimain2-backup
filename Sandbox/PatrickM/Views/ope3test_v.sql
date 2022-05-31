create view patrickm.ope3test_v as 
select  fanid, 
		a.CINID, 
		c.BrandID, 
		Propensity
from sandbox.patrickm.ope3testcustomers as a
left join (select BrandID, CINID, Propensity from Warehouse.Prototype.OPECustomerPropensity
				union
		   select 3116 as BrandID, CINID, 0 as propensity from Warehouse.Prototype.OPECustomerPropensity group by CINID
				union
		   select 3346 as BrandID, CINID, 0 as propensity from Warehouse.Prototype.OPECustomerPropensity group by CINID
		   ) as c
	on a.CINID = c.CINID
	where EndDate is NULL and ControlFlag = 0