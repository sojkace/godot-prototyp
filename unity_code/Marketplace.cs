using System.Collections;
using System.Collections.Generic;
using Unity.Burst.CompilerServices;
using UnityEngine;

public class Marketplace : Building
{
    [Header("Settings Marketplace")]
    [SerializeField]
    private int cycleOfUpdates = 3;
    [SerializeField]
    private int numberOfCards = 6;
    [SerializeField]
    private Mesh MPAktivMesh;
    [SerializeField]
    private Mesh MPDeaktiveMesh;
    [Header("Marketplace Dont Touch")]
    [SerializeField]
    public List<ItemCard> itemsInMaketplace = new List<ItemCard>();
    public bool MarketplaceUsedThisRound = false;
    private int roundUntilUpdate;
    

    // Start is called before the first frame update
    void Start()
    {
        roundUntilUpdate = cycleOfUpdates;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public override void SetUp(Vector3Int newCoordinats)
    {
        base.SetUp(newCoordinats);
        AddnewItems(numberOfCards);
        //if (type == "Marketplace")
        //{
        //    for (int i = 0; i <= 2; i++)
        //    {
        //        bool itemAdded = false;
        //        Item preNewItem = ItemMaster.instance.itemsPrefab[Random.Range(0, ItemMaster.instance.itemsPrefab.Count)];
        //        foreach (Item exI in itemsInMaketplace)
        //        {
        //            if (preNewItem.type == exI.type)
        //            {
        //                exI.AddItemOfThisType(1);
        //                itemAdded = true;
        //            }
        //        }
        //        if (!itemAdded)
        //        {
        //            Item newItem = Instantiate(preNewItem, ItemMaster.instance.marketplaceHolder);
        //            newItem.gameObject.SetActive(false);
        //            newItem.SetUp(1, "Marketplace");
        //            itemsInMaketplace.Add(newItem);
        //        }

        //    }
        //}
    }

    void AddnewItems(int num)
    {
        roundUntilUpdate = cycleOfUpdates;
        ItemMaster.instance.AddNewItemsInMarketplace(this, num);
    }


    public override void UptdateData(Vector3Int newCoordinats)
    {
        base.UptdateData(newCoordinats);
    }

    public override void Clicked()
    {
        base.Clicked();
        Debug.Log("Open Shop");
        UiMaster.instance.OpenMarketplace(this);
    }

    public override void NextRound()
    {
        base.NextRound();
        SetState(true);
        roundUntilUpdate--;
        if(roundUntilUpdate == 0)
        {
            AddnewItems(numberOfCards);
        }
    }

    public void SetState(bool state)
    {
        MarketplaceUsedThisRound = !state;
        if (state)
        {
            GetComponent<MeshFilter>().mesh = MPAktivMesh;
        }
        else
        {
            GetComponent<MeshFilter>().mesh = MPDeaktiveMesh;
        }
    }
}
