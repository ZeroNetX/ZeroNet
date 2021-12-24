import base64
import hashlib

def sign(data, privatekey):
    from lib import Ed25519
    
    prv_key = base64.b64decode(privatekey)
    pub_key = Ed25519.publickey_unsafe(prv_key)
    sign = Ed25519.signature_unsafe(data, prv_key, pub_key)
    
    return sign

def verify(data, publickey, sign):
    from lib import Ed25519

    try:
        valid = Ed25519.checkvalid(sign, data, publickey) 
        valid = 'SHA-256'
    
    except Exception as err:
        print(err)
        valid = False
    
    return valid

def privatekeyToPublickey(privatekey):
    from lib import Ed25519

    prv_key = base64.b64decode(privatekey)
    pub_key = Ed25519.publickey_unsafe(prv_key)
      
    return pub_key

def publickeyToOnion(publickey):
    from lib import Ed25519

    addr = Ed25519.publickey_to_onionaddress(publickey)[:-6]
    return addr
