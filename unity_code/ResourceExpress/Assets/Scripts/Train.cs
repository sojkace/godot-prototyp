using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Train : MonoBehaviour
{
 
    [Header("Settings")]
    [SerializeField]
    public  int capacity;
    [SerializeField]
    List<Mesh> trainContent;
    [Header("Dont Touch")]
    public int numberOfItems = 0;
    public Vector3Int coordinats;
    public int currentRailPosition;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    // collect gold with animation
    public void CollectItem()
    {
        Debug.Log("Collect");
        GetComponent<Animator>().Play("Collect");
        numberOfItems++;
        GetComponent<MeshFilter>().mesh = trainContent[numberOfItems];
    }

    // move train smothe to position and when train is in Resourcearea the Mine will be set up
    // when train at PS Gamemaster will know
    public IEnumerator MoveToPosition(Vector3 position, Grid grid)
    {

        float timeElapsed = 0;
        Vector3 startPosition = transform.position;
        while (timeElapsed < 1)
        {
            float t = Mathf.SmoothStep(0, 1, timeElapsed / 1);
            transform.position = Vector3.Lerp(startPosition, position, t);
            timeElapsed += Time.deltaTime;
            yield return null;
        }
        transform.position = position;
        coordinats = grid.WorldToCell(transform.position);

        if(currentRailPosition != 0)
        { 
            foreach (Building b in BuildingMaster.instance.buildings)
            {
                if (b.coordinats == coordinats)
                {
                    foreach (Mine re in b.resourceBuildings)
                    {
                        re.trainsInMyResource.Add(this);
                    }
                }
            }
        }
        else
        {
            TrainMaster.instance.TrainEnteredPS(this);
        }
    }


}
