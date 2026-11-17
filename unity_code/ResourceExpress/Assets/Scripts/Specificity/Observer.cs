using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Observer : Building
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
        if (type == "Observer")
        {
            foreach (Transform co in coordinatsToCheck)
            {
                foreach (Building b in BuildingMaster.instance.buildings)
                {
                    if (b.transform.position == co.position)
                    {
                        b.inObeservationArea = true;
                    }
                }
            }
        }
    }

    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
        if (type == "Observer")
        {
            foreach (Transform co in coordinatsToCheck)
            {
                foreach (Building b in BuildingMaster.instance.buildings)
                {
                    if (b.transform.position == co.position)
                    {
                        b.inObeservationArea = true;
                    }
                }
            }
        }
    }
}
