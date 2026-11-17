using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using UnityEngine;

public class Itemcrafter : Building
{
    [Header("Animator for Itemcrafter")]
    [SerializeField]
    private Animator collectIcon;

    [Header("Dont Touch for Itemcrafter")]
    public Item resource;
    private bool canCollectItems;
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
        if (type == "ItemCrafter")
        { 
            //SetCollectIconAnimation(true);
        }
    }

    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
    }

    public void CollectItems()
    {
        if (canCollectItems)
        {
            //SetCollectIconAnimation(false);
            for (int i = 0; i < level * 2; i++)
            {
                ItemMaster.instance.AddItem(resource.type);
            }

        }
    }

    public void SetCollectIconAnimation(bool state)
    {
        if (state)
        {
            //random Item
            int random = Random.Range(0, ItemMaster.instance.itemsPrefab.Count);
            resource = ItemMaster.instance.itemsPrefab[random];
            collectIcon.GetComponent<MeshRenderer>().materials[1].mainTexture = resource.image.texture;
        }
        collectIcon.GetComponent<MeshRenderer>().enabled = state;
        collectIcon.SetBool("Animation", state);
        canCollectItems = state;
    }
}
