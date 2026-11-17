using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Flag : Building
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public override void SetUp(Vector3Int newCoordinats)
    {
        base.SetUp(newCoordinats);
        if (type == "FlagNormal" || type == "FlagPointy")
        {
            foreach (Transform co in coordinatsToCheck)
            {
                BuildingMaster.instance.PlaceObj(BuildingMaster.instance.dirtPrefab, co.position);
            }
        }
    }

    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
    }
}
