/*
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is GzipHTTPService.
 *
 * The Initial Developer of the Original Code is
 * Anirudh Sasikumar (http://anirudhs.chaosnet.org/).
 * Portions created by the Initial Developer are Copyright (C) 2008
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *  Mark Lynch (mark@learnosity.com)  
 *    2009-03-19 - Added AIR header code and handling of non gzipped file
 */
package com.gzip.rpc
{
    /* use Paul Robertson's GZIP encoder */
    import com.gzip.utils.GZIPBytesEncoder;
    
    import flash.errors.IllegalOperationError;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;
    
    import mx.core.mx_internal;
    import mx.messaging.Channel;
    import mx.messaging.ChannelSet;
    import mx.messaging.messages.IMessage;
    import mx.rpc.AsyncToken;
    import mx.rpc.http.mxml.HTTPService;
  
    use namespace mx_internal;
    
    public class GzipHTTPService extends HTTPService
    {
        
    	protected static var binaryChannel:Channel;
    	protected static var binaryChannelSet:ChannelSet;
        
        public function GzipHTTPService(rootURL:String=null, destination:String=null)
        {
            super(rootURL, destination);
   			//If using AIR then set accept GZIP
			if(Capabilities.playerType == "Desktop")
			{
				this.headers = {'Accept-Encoding':'gzip'};
			}
        }
        
        override public function send(parameters:Object = null):AsyncToken
    	{
            if ( useProxy == false )
            {
                /* force the use of our binary channel */
                if ( binaryChannelSet == null )
                {
                    var dcs:ChannelSet = new ChannelSet();
                    binaryChannel = new DirectHTTPBinaryChannel("direct_http_binary_channel");
                    dcs.addChannel(binaryChannel);            
                    channelSet = dcs
            		binaryChannelSet = dcs;
                }
                else if ( channelSet != binaryChannelSet )
                {
                    channelSet = binaryChannelSet;
                }       			
            }    		
            return super.send(parameters);	
    	}
        
        override mx_internal function processResult(message:IMessage, token:AsyncToken):Boolean
        {
            var body:Object = message.body;
            
            if (body == null )
            {
                _result = null;
                return true;
            }
            else if ( body is ByteArray )
            {
                var barr:ByteArray = body as ByteArray;
                
                try{
                	var encoder:GZIPBytesEncoder = new GZIPBytesEncoder();
                	/* decode the gzip encoded result */
                	message.body = encoder.uncompressToByteArray(barr).toString();
                }catch(error:IllegalOperationError){
                	//Not gzip compressed - assume utf8
                	barr.position = 0;//reset to start of bytearray
                	message.body = barr.readUTFBytes(barr.length);
                }
                /* pass it on to HTTPService */
                return super.processResult(message, token);				
            }
            return false;
        }
    }
}