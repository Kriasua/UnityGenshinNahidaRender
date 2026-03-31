using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeadForward_Right : MonoBehaviour
{

    public Transform headTransform;
    public Transform headForward;
    public Transform headRight;
    public Material faceMaterial;
    
    // Start is called before the first frame update
    void Start()
    {
        Update();
    }
    
    
    // Update is called once per frame
    void Update()
    {
        Vector3 forwardVector = headForward.position - headTransform.position;
        Vector3 rightVector = headRight.position - headTransform.position;

        forwardVector=forwardVector.normalized;
        rightVector = rightVector.normalized;
        
        Vector4 forwardVector4 = new Vector4(forwardVector.x,forwardVector.y,forwardVector.z);
        Vector4 rightVector4 = new Vector4(rightVector.x,rightVector.y,rightVector.z);
        
        faceMaterial.SetVector("_ForwardVector", forwardVector4);
        faceMaterial.SetVector("_RightVector", rightVector4);
        

    }
    
    
    
    
}
