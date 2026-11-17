using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;


public class Dirt : Building
{
    [Header("Dont Touch for Dirt")]
    public Item resource;
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
        
    }

    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
    }
}
